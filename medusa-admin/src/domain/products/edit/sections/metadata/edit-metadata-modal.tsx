import { Product } from "@medusajs/medusa"
import {
  UseFormReturn,
  useFieldArray,
  useForm,
  useWatch,
} from "react-hook-form"
import Button from "../../../../../components/fundamentals/button"
import Modal from "../../../../../components/molecules/modal"
import EditFlowMetadataForm, {
  EditFlowMetadataFormType,
} from "../../../components/metadata-form/edit-flow-metadata-form"
import useEditProductActions from "../../hooks/use-edit-product-actions"
import { MetadataField } from "../../../../../components/organisms/metadata"

type Props = {
  form: UseFormReturn<EditFlowMetadataFormType, any>
  product: Product
  onClose: () => void
  open: boolean
  isDuplicate?: boolean
}

const EditMetadataModal = ({
  form,
  product,
  onClose,
  open,
  isDuplicate = false,
}: Props) => {
  const { onUpdate, updating } = useEditProductActions(product.id)
  const { control } = form
  const {
    formState: { isDirty },
    handleSubmit,
    reset,
  } = form
  const watchedMetadata = useWatch({
    control: control,
    name: "data",
  })

  const handleClose = () => {
    reset({ data: watchedMetadata })
    onClose()
  }

  const onSubmit = handleSubmit((data) => {
    const metadata: Record<string, any> = {}
    for (const meta of data.data) {
      metadata[meta.key] = meta.value
    }
    onUpdate(
      {
        metadata: {
          specs: metadata,
        },
      },
      handleClose
    )
  })

  return (
    <Modal open={open} handleClose={handleClose}>
      <Modal.Header handleClose={handleClose}>
        <h1 className="inter-xlarge-semibold">Edit Metadata</h1>
      </Modal.Header>
      <form onSubmit={onSubmit} noValidate>
        <Modal.Content>
          <EditFlowMetadataForm form={form} />
        </Modal.Content>
        <Modal.Footer>
          <div className="w-full flex items-center gap-x-xsmall justify-end">
            <Button
              variant="secondary"
              size="small"
              type="button"
              onClick={handleClose}
            >
              Cancel
            </Button>
            <Button
              variant="primary"
              size="small"
              type="submit"
              loading={updating}
            >
              Save and close
            </Button>
          </div>
        </Modal.Footer>
      </form>
    </Modal>
  )
}

export default EditMetadataModal
