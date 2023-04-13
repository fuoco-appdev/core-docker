import { useFieldArray, UseFormReturn, useWatch } from "react-hook-form"
import IconTooltip from "../../../../../components/molecules/icon-tooltip"
import Accordion from "../../../../../components/organisms/accordion"
import Metadata, {
  MetadataField,
} from "../../../../../components/organisms/metadata"
import { useEffect, useLayoutEffect, useState } from "react"

export type EditFlowMetadataFormType = {
  data: MetadataField[]
}

type Props = {
  form: UseFormReturn<EditFlowMetadataFormType, any>
}

const EditFlowMetadataForm = ({ form }: Props) => {
  const { register, control } = form
  const { replace: replaceMetadata } = useFieldArray({
    control,
    name: "data",
    shouldUnregister: true,
  })
  const watchedMetadata = useWatch({
    control: control,
    name: "data",
  })
  const [metadata, setMetadata] = useState<MetadataField[]>(watchedMetadata)

  useEffect(() => {
    register("data")
  }, [])

  useLayoutEffect(() => {
    replaceMetadata(metadata)
  }, [metadata])

  return (
    <>
      <p className="text-grey-50 inter-base-regular">
        Edit metadata of this product.
      </p>
      <div className="mt-large">
        <div>
          <div className="flex items-center gap-x-2xsmall">
            <h3 className="inter-base-semibold">Product metadata</h3>
            <IconTooltip
              type="info"
              content="Metadata are used to define specifications"
            />
          </div>
          <div className="mt-xlarge w-full">
            <Metadata setMetadata={setMetadata} metadata={metadata} />
          </div>
        </div>
      </div>
    </>
  )
}

export default EditFlowMetadataForm
