import { useMemo } from "react"
import { Column, useTable } from "react-table"
import EditIcon from "../../../../../components/fundamentals/icons/edit-icon"
import TrashIcon from "../../../../../components/fundamentals/icons/trash-icon"
import Actionables from "../../../../../components/molecules/actionables"
import Table from "../../../../../components/molecules/table"
import { MetadataField } from "../../../../../components/organisms/metadata"
import { UseFormReturn, useFieldArray, useWatch } from "react-hook-form"
import { EditFlowMetadataFormType } from "../../../components/metadata-form/edit-flow-metadata-form"
import useEditProductActions from "../../hooks/use-edit-product-actions"
import { Product } from "@medusajs/medusa"

type Props = {
  form: UseFormReturn<EditFlowMetadataFormType, any>
  product: Product
}

export const useMetadataTableColumns = () => {
  const columns = useMemo<Column<MetadataField>[]>(
    () => [
      {
        Header: "Key",
        id: "key",
        accessor: "key",
      },
      {
        Header: "Value",
        id: "value",
        accessor: "value",
      },
    ],
    []
  )

  return columns
}

const MetadataTable = ({ form, product }: Props) => {
  const columns = useMetadataTableColumns()
  const { control, reset } = form
  const { onUpdate, onDeleteProductOption } = useEditProductActions(product.id)
  const watchedMetadata = useWatch({
    control: control,
    name: "data",
  })
  const { remove: removeMetadata } = useFieldArray({
    control,
    name: "data",
    shouldUnregister: true,
  })

  const deleteMetadata = (key: string) => {
    const index = watchedMetadata.findIndex((value) => value.key === key)
    const metadataCopy = watchedMetadata
    metadataCopy.splice(index, 1)
    removeMetadata(index)

    const metadata: Record<string, any> = {}
    for (const meta of metadataCopy) {
      metadata[meta.key] = meta.value
    }
    onUpdate(
      {
        metadata: {
          specs: metadata,
        },
      },
      () => reset({ data: metadataCopy })
    )
  }

  const { getTableProps, getTableBodyProps, headerGroups, rows, prepareRow } =
    useTable({
      columns,
      data: watchedMetadata,
      defaultColumn: {
        width: "auto",
      },
    })

  return (
    <Table {...getTableProps()} className="table-fixed">
      <Table.Head>
        {headerGroups?.map((headerGroup) => (
          <Table.HeadRow {...headerGroup.getHeaderGroupProps()}>
            {headerGroup.headers.map((col) => (
              <Table.HeadCell {...col.getHeaderProps()}>
                {col.render("Header")}
              </Table.HeadCell>
            ))}
          </Table.HeadRow>
        ))}
      </Table.Head>
      <Table.Body {...getTableBodyProps()}>
        {rows.map((row) => {
          prepareRow(row)
          return (
            <Table.Row color={"inherit"} {...row.getRowProps()}>
              {row.cells.map((cell) => {
                return (
                  <Table.Cell {...cell.getCellProps()}>
                    {cell.render("Cell")}
                  </Table.Cell>
                )
              })}
              <Table.Cell>
                <div className="float-right">
                  <Actionables
                    forceDropdown
                    actions={[
                      {
                        label: "Delete Variant",
                        onClick: () => deleteMetadata(row.original.key),
                        icon: <TrashIcon size="20" />,
                        variant: "danger",
                      },
                    ]}
                  />
                </div>
              </Table.Cell>
            </Table.Row>
          )
        })}
      </Table.Body>
    </Table>
  )
}

export default MetadataTable
